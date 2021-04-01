# gitinit

Just a little tool to generate project boilerplates that I like.

Available templates:
- `empty` Just the git, README.md and JetBrains-friendly .gitignore
- `node` Empty node.js project with package.json and prettier
- `ts_module` Node.js project with typescript, jest and eslint
- `ts_cra` CreateReactApp with typescript, prettier and eslint

### Installation

```
cd /opt
sudo git clone https://github.com/panta82/gitinit
cd /opt/gitinit
sudo ./install.sh
```

### Usage

```
mkdir my-project-name
cd my-project-name
gitinit
```
