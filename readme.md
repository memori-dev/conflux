# conflux

### backend
dump sqlite table
`sqlite3 conflux/db/test.sqlite '.mode table' '.nullvalue NULL' 'select * from {TABLE_NAME};'`

### frontend
build
`bun build src/frontend/js/{}/{}.js --outdir src/frontend/bundle`
monitor rebuild
`while inotifywait -e modify -r src/frontend/js/{}; do bun build src/frontend/js/{}/{}.js --outdir src/frontend/bundle; done`

### notes
temp fixes were made for `zig-sqlite` and `zap` to work with 0.16

### resources
sqlite
* https://github.com/vrischmann/zig-sqlite/
* https://www.sqlite.org/docs.html
* https://www.reddit.com/r/golang/comments/16xswxd/concurrency_when_writing_data_into_sqlite/

zap
* https://github.com/zigzap/zap/
	* https://github.com/zigzap/zap/tree/master?tab=readme-ov-file#new-app-based-examples
* https://github.com/boazsegev/facil.io
