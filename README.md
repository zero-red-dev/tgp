# 🚀 TypeScript Project Generator
Tired of the repetitive npm create vite@latest and then tweaking the config for the hundredth time? This script is your solution. It's a powerful, flexible command-line tool that scaffolds TypeScript projects tailored to your specific needs.

## Usage
### Quick start
Initialize a new project with a single command. Choose from two specialized templates:

- __vite-web__: For web applications - a TypeScript development environment powered by Vite and SWC for optimal performance

- __vite-node__: For Node.js applications - a robust TypeScript setup for server-side development

__Create a web application:__
```bash
curl -fsSL https://raw.githubusercontent.com/zero-red-dev/tgp/refs/heads/zero/tpg.sh | bash -s my-webapp-name vite-web
```

__Create a Node.js application:__
```bash
curl -fsSL https://raw.githubusercontent.com/zero-red-dev/tgp/refs/heads/zero/tpg.sh | bash -s my-nodeapp-name vite-node
```

Simply replace my-webapp-name or my-nodeapp-name with your desired project name.

## Why use this script?
- Save Time: Eliminate boilerplate setup and start writing your actual code faster.

- Consistency: Ensure all your projects have a standardized, well-configured starting point.

- Flexibility: Not a one-size-fits-all solution. Generate the perfect foundation for any TypeScript task.

### ✨ What it does now:
- Bootstraps a hardcoded, vanilla Vite + TypeScript + SWC project.


## 🔮 The Future Roadmap:
- The goal is to make this an interactive and powerful generator. Future versions will allow you to specify:

- Project Type: Web (Vite, Webpack), Node.js, CLI and Library.

- Package Manager: npm, yarn, pnpm.

- Tooling: Linting (ESLint), Formatting (Prettier), Testing frameworks.

- Configuration: Customizable tsconfig.json and other build tool settings.

## License and AI Training
This project is licensed under the GNU General Public License v3.0 (GPLv3).

The authors of this software consider the use of this code, including its source code, documentation, and any other project artifacts, for the training of artificial intelligence (AI) systems (including but not limited to machine learning, large language models, and other AI technologies) to be creating a derivative work. As such, any entity using this code for such purposes must comply with the terms of the GPLv3. This includes, but is not limited to, making the entire source code of the AI system that uses this code available under the same GPLv3 license.

If you wish to use this code for AI training without being subject to the GPLv3, please contact the authors to negotiate a separate license.
