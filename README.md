<div align="center">

# asdf-nodeapp ![Build](https://github.com/mattysweeps/asdf-nodeapp/workflows/Build/badge.svg) ![Lint](https://github.com/mattysweeps/asdf-nodeapp/workflows/Lint/badge.svg)

A generic Node.js Application plugin for the [asdf version manager](https://asdf-vm.com).

</div>

**What is a "Node.js Application"?**

For purposes of this plugin, a Node.js Application is a program that _happens_ to be written in Node.js, but otherwise behaves like a regular command-line tool.

Examples of Node.js Applications are [bash-language-server](https://www.npmjs.com/package/bash-language-server) and [@angular/cli](https://www.npmjs.com/package/@angular/cli). See below for more compatible applications.

# Dependencies

- `node` and `npm` >= 16
- OR [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) installed

# Install

Plugin:

```shell
asdf plugin add <node app> https://github.com/mattysweeps/asdf-nodeapp.git
# for example
asdf plugin add bash-language-server https://github.com/mattysweeps/asdf-nodeapp.git
```

Example using `bash-language-server`:

```shell
# Show all installable versions
asdf list-all bash-language-server

# Install specific version
asdf install bash-language-server latest

# Set a version globally (on your ~/.tool-versions file)
asdf global bash-language-server latest

# Now bash-language-server commands are available
bash-language-server --help
```

## Compatible Node.js Applications

This is a non-exhaustive list of Node.js Applications that work with this plugin.

| App                                                      | Command to add Plugin                                                                       | Notes                                                              |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [@angular/cli](https://www.npmjs.com/package/@angular/cli) | `asdf plugin add @angular/cli https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [bash-language-server](https://www.npmjs.com/package/bash-language-server) | `asdf plugin add bash-language-server https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [create-react-app](https://www.npmjs.com/package/create-react-app) | `asdf plugin add create-react-app https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [eslint](https://www.npmjs.com/package/eslint) | `asdf plugin add eslint https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [gatsby-cli](https://www.npmjs.com/package/gatsby-cli) | `asdf plugin add gatsby-cli https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [netlify-cli](https://www.npmjs.com/package/netlify-cli) | `asdf plugin add netlify-cli https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [nodemon](https://www.npmjs.com/package/nodemon) | `asdf plugin add nodemon https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [npm](https://www.npmjs.com/package/npm) | `asdf plugin add npm https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [pm2](https://www.npmjs.com/package/pm2) | `asdf plugin add pm2 https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [prettier](https://www.npmjs.com/package/prettier) | `asdf plugin add prettier https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [typescript](https://www.npmjs.com/package/typescript) | `asdf plugin add typescript https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [vue-cli](https://www.npmjs.com/package/@vue/cli) | `asdf plugin add @vue/cli https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [webpack-cli](https://www.npmjs.com/package/webpack-cli) | `asdf plugin add webpack-cli https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |
| [yarn](https://www.npmjs.com/package/yarn) | `asdf plugin add yarn https://github.com/mattysweeps/asdf-nodeapp.git` |                                                                    |

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.

# How it Works

asdf-nodeapp is a lot more complex than most asdf plugins since it's designed to work with generic Node.js Applications, and challenges that come with Node.js package management.

asdf-nodeapp uses the same technique as [asdf-hashicorp](https://github.com/asdf-community/asdf-hashicorp) to use a single plugin for multiple tools.

When installing a tool, asdf-nodeapp creates a fresh directory with its own `node_modules` and npm-installs the package matching the plugin name. Then it symlinks the binaries provided by the package to make them available to asdf.

## Node.js Resolution

To run Node.js Applications, you need Node.js. The Node.js runtime is chosen
in the following order:

1. Use `ASDF_NODEAPP_DEFAULT_NODE_PATH` if it is set
2. Use the global node `/usr/local/bin/node` if it exists
3. Use the `node` in our path
4. Use the `node` set by the asdf-nodejs plugin

## asdf-nodejs Integration (Experimental)

Here we color outside the lines a bit :)

asdf-nodejs supports installing a Node.js App with a _specific_ Node.js version using a special syntax. This feature requires the [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) plugin to be installed.

The general form is:

```shell
asdf <app> install <app-version>@<node-version>
```

For example, to install `bash-language-server` 3.1.0 with Node.js 18.17.0:

```shell
asdf bash-language-server install 3.1.0@18.17.0
```

Node.js Apps with different Node.js versions and Node.js itself can all happily co-exist in the same project. For example, take this `.tool-versions`:

```shell
nodejs 18.17.0
bash-language-server 3.1.0
eslint 8.45.0@16.20.0
prettier 3.0.0@18.17.0
```

- `bash-language-server` will be installed with the global Node.js (see Node.js Resolution), in an isolated directory
- Node.js 16.20.0 will be used for `eslint` installation
- `prettier` will be installed with Node.js 18.17.0, but isolated from the project's Node.js, which is also 18.17.0.

# Configuration

## Environment Variables

- `ASDF_NODEAPP_INCLUDE_DEPS` - when set to `1`, this plugin will consider the executables of the dependencies of the installed package as well. For example, when installing `@angular/cli`, additional commands from its dependencies might also be made available.
- `ASDF_NODEAPP_DEFAULT_NODE_PATH` - Path to a `node` binary this plugin should use. Default is unset. See Node.js Resolution section for more details.
- `ASDF_NODEAPP_DEBUG` - Set to `1` for additional logging

# Background and Inspiration

asdf-nodeapp was inspired by [asdf-hashicorp](https://github.com/asdf-community/asdf-hashicorp) and [asdf-pyapp](https://github.com/amrox/asdf-pyapp). Big thanks to the creators, contributors, and maintainers of both these projects.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/mattysweeps/asdf-nodeapp/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Matthew Broomfield](https://github.com/mattysweeps/)

---

*This project is based on [asdf-pyapp](https://github.com/amrox/asdf-pyapp) by Andy Mroczkowski, licensed under MIT.*
