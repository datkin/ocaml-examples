# ocaml-examples
Examples of building ocaml code and using ocaml tools.

## opam

### Make a new environment in opam

```
$ opam switch install <environment name of your choice> -alias-of <compiler name>
$ eval $(opam config env)
```

### Switching between environments

```
$ opam switch <env name> && eval $(opam config env)
```

### Checking out package source

```
$ opam source <package name>
```

This will just checkout the code at whatever revision would be built by default for your ocaml version.

### Install from source

First, tell opam where to look for the package:

```
$ opam pin <package name> <path>
```

You'll be prompted to install now. You can later run:

```
$ opam install <package name>
```

Or you can rebuild following a changew ith:

```
$ opam update <package name>
```


### Adding a compiler

I'm not sure there's a way to add a "local" compiler definition. I think you
need to make your own local opam repository and define the compiler there.

1. Make your repo and add some definitions. I copied a compiler definition from
   the prop repos, and modified it slightly.

1. Register the repo with opam. I think I used `local` for <name>.

   ```
   $ opam repo add <name> <path>
   ```

1. Now you can access the compiler you defined there.

1. If you change anything in the repo, you can update the `opam update`.
