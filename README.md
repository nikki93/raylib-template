## Build and run

Submodules are used for dependencies, so make sure to have cloned the
repository with `git clone --recursive` or do `git submodule update --init --recursive`
after cloning. You'll need to have CMake installed.

### Desktop

Just run the following command. On Windows the run script needs WSL.
```
./run.sh release
```

### Web

For first-time setup, run:
```
./run.sh web-init
```

Then to build, run:
```
./run.sh web-release
```

You'll then need to serve and load 'build/web-release' in a browser. You can do
this with the following command, which needs Node / NPM, and lets you view the
website at http://localhost:9002. You can use any other web server too.
```
./run.sh web-serve-release
```
