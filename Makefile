F = specs

s:
	node_modules/nodemon/bin/nodemon.js

t:
	node_modules/mocha/bin/mocha --grep integration --invert --recursive --check-leaks --compilers coffee:coffee-script/register --require specs/helpers/index.coffee $F

ta:
	node_modules/mocha/bin/mocha --recursive --check-leaks --compilers coffee:coffee-script/register --require specs/helpers/index.coffee $F

c:
	rm -fr lib/
	coffee -o lib src
	coffee -c app.coffee
