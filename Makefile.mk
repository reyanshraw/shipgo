.PHONY: lint test release clean

lint:
	bash scripts/lint.sh

test:
	bash scripts/test.sh

release:
	bash scripts/release.sh

clean:
	rm -rf dist/ release/