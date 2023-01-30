import base64
import gc
import hashlib
import io
import itertools
import random
from collections import deque
from typing import List, Tuple

import matplotlib as mpl
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import numpy as np
import seagull as sg
import seagull.lifeforms as lf
from PIL import Image
from matplotlib.backends.backend_agg import FigureCanvasAgg
from scipy.signal import convolve2d


def hasher(string: str) -> str:
    h = hashlib.sha224()
    h.update(string.encode("utf-8"))
    value = h.hexdigest()
    return "".join(filter(str.isdigit, value))


def get_seeds(h: str) -> Tuple[int, List[int]]:
    """Generate 10 seeds"""
    # The first 10 integers will make up the sprite
    sprite_seed = int(h[:9])
    color_seeds = [int("".join(n)) for n in window(h[::-1], 4)]
    return sprite_seed, color_seeds


def window(seq, n=4):
    it = iter(seq)
    win = deque((next(it, None) for _ in range(n)), maxlen=n)
    yield tuple(win)
    append = win.append
    for e in it:
        append(e)
        yield tuple(win)


def generate_sprite(
        # n_iters : int
        # Number of iterations to run Conway's Game of Life.
        n_iters: int = 1,
        # extinction : float (0.0 to 1.0)
        # Controls how many dead cells will stay dead on the next iteration
        # Default is 0.125 (around 1 cell)
        extinction: float = 0.125,
        # survival: float (0.0 to 1.0)
        # Size of the generated sprite in pixels. Default is 180 for 180 x 180px.
        survival: float = 0.375,
        # size : int
        # Random seed for the Sprite. Default is None
        size: int = 256,
        # sprite_seed : int (optional)
        # Controls how many live cells will stay alive on the next iteration.
        # Default is 0.375 (around 3 cells)
        sprite_seed: int = None,
        # color_seeds : list (optional)
        # Random seed for the colors. Default is None
        color_seeds: List[int] = None,
):
    board = sg.Board(size=(8, 4))

    if sprite_seed:
        np.random.seed(sprite_seed)
    noise = np.random.choice([0, 1], size=(8, 4))
    custom_lf = lf.Custom(noise)
    board.add(custom_lf, loc=(0, 0))

    sim = sg.Simulator(board)
    sim.run(
        _custom_rule,
        iters=n_iters,
        n_extinct=int(extinction * 8),
        n_survive=int(survival * 8),
    )
    fstate = sim.get_history()[-1]

    sprite = np.hstack([fstate, np.fliplr(fstate)])
    sprite = np.pad(sprite, mode="constant", pad_width=1, constant_values=1)
    sprite_with_outline = _add_outline(sprite)
    sprite_gradient = _get_gradient(sprite_with_outline)
    sprite_final = _combine(sprite_with_outline, sprite_gradient)

    iterator = list(_group(3, color_seeds))[:3] if color_seeds else [None] * 3
    random_colors = [_color(seeds) for seeds in iterator]
    base_colors = ["black", "#f2f2f2"]
    colors = base_colors + random_colors
    cm.unregister_cmap("custom_r")
    cm.register_cmap(
        cmap=mpl.colors.LinearSegmentedColormap.from_list(
            "custom", colors
        ).reversed(),
        # force=True,
    )

    fig, axs = plt.subplots(1, 1, figsize=(1, 1), dpi=size)
    axs = fig.add_axes([0, 0, 1, 1], xticks=[], yticks=[], frameon=False)
    axs.imshow(sprite_final, cmap="custom_r", interpolation="nearest")

    binary_output = io.BytesIO()

    FigureCanvasAgg(fig).print_png(binary_output)
    base64_output = base64.b64encode(binary_output.getvalue())
    plt.close(fig)  # close the window to prevent memory leaks
    gc.collect()

    img = Image.open(io.BytesIO(base64.b64decode(base64_output)))
    img = img.convert("RGBA")
    datas = img.getdata()
    newData = []
    pickleToRemove = None
    for item in datas:
        if pickleToRemove is None:
            pickleToRemove = item

        if item[0] == pickleToRemove[0] and item[1] == pickleToRemove[1] and item[2] == pickleToRemove[2]:
            newData.append((0, 0, 0, 0))
        else:
            newData.append(item)
    img.putdata(newData)

    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    base64_output = base64.b64encode(buffered.getvalue())

    return base64_output


def _custom_rule(
        X: np.ndarray, n_extinct: int = 3, n_survive: int = 3
) -> np.ndarray:
    """Custom Conway's Rule"""
    n = convolve2d(X, np.ones((3, 3)), mode="same", boundary="fill") - X
    reproduction_rule = (X == 0) & (n <= n_extinct)
    stasis_rule = (X == 1) & ((n == 2) | (n == n_survive))
    return reproduction_rule | stasis_rule


def _color(seeds: Tuple[int, int, int] = None) -> str:
    """Returns a random hex code"""
    hex_values = []
    for i in range(3):
        if seeds:
            random.seed(seeds[i])
        h = random.randint(0, 255)
        hex_values.append(h)
    return "#{:02X}{:02X}{:02X}".format(*hex_values)


def _add_outline(mat: np.ndarray) -> np.ndarray:
    """Create an outline given a sprite image
    It traverses the matrix and looks for the body of the sprite, as
    represented by 0 values. Once it founds one, it looks around its neighbors
    and change all background values (represented as 1) into an outline.
    Parameters
    ----------
    mat : np.ndarray
        The input sprite image
    Returns
    -------
    np.ndarray
        The sprite image with outline
    """
    m = np.ones(mat.shape)
    for idx, orig_val in np.ndenumerate(mat):
        x, y = idx
        neighbors = [(x, y + 1), (x + 1, y), (x, y - 1), (x - 1, y)]
        if orig_val == 0:
            m[idx] = 0  # Set the coordinate in the new matrix as 0
            for n_coord in neighbors:
                try:
                    m[n_coord] = 0.5 if mat[n_coord] == 1 else 0
                except IndexError:
                    pass

    m = np.pad(m, mode="constant", pad_width=1, constant_values=1)

    # I need to switch some values so that I get the colors right.
    # Need to make all 0.5 (outline) as 1, and all 1 (backround)
    # as 0.5
    m[m == 1] = np.inf
    m[m == 0.5] = 1
    m[m == np.inf] = 0.5

    return m


def _get_gradient(
        mat: np.ndarray, map_range: Tuple[float, float] = (0.2, 0.25)
) -> np.ndarray:
    """Get gradient of an outline sprite
    We use gradient as a way to shade the body of the sprite. It is a crude
    approach, but it works most of the time.
    Parameters
    ----------
    mat : np.ndarray
        The input sprite with outline
    map_range : tuple of floats
        Map the gradients within a certain set of values. The default is
        between 0.2 and 0.25 because those values look better in the color map.
    Returns
    -------
    np.ndarray
        The sprite with shading
    """
    grad = np.gradient(mat)[0]

    def _remap(new_range, matrix):
        old_min, old_max = np.min(matrix), np.max(matrix)
        new_min, new_max = new_range
        old = old_max - old_min
        new = new_max - new_min
        return (((matrix - old_min) * new) / old) + new_min

    sprite_with_gradient = _remap(map_range, grad)
    return sprite_with_gradient


def _combine(mat_outline: np.ndarray, mat_gradient: np.ndarray) -> np.ndarray:
    """Combine the sprite with outline and the one with gradients
    Parameters
    ----------
    mat_outline: np.ndarray
        The sprite with outline
    mat_gradient: np.ndarray
        The sprite with gradient
    Returns
    -------
    np.ndarray
        The final black-and-white sprite image before coloring
    """
    mat_final = np.copy(mat_outline)
    mask = mat_outline == 0
    mat_final[mask] = mat_gradient[mask]
    return mat_final


def _group(n, it):
    args = [iter(it)] * n
    return itertools.zip_longest(fillvalue=None, *args)

constPrefix = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAA"

if __name__ == "__main__":
    f = open("avatars.txt", "a")

    for i in range(0, 128):
        q: str = None
        seeds = get_seeds(hasher(q)) if q else (None, None)
        sprite_seed, color_seeds = seeds

        b64 = generate_sprite(
            sprite_seed=sprite_seed,
            color_seeds=color_seeds,
        )

        out = str(b64)[2:-1]
        out = out[len(constPrefix):]

        f.write(out + "\n")

    f.close()
