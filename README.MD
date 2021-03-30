
=====================
How to run the same steps and stages as in CI?

To be able to run the same steps and stages as in CI on the localhost there are implemented BASH scripts stored in every project's repo in the folder ./ci-work/\*

To run them you must have a Linux OS with Docker Engine and Docker Compose installed.
Some stages could require SUDO access.

0.  Prepare the Docker images to compile the project:
    $bash ci-work/00-prepare.sh              # And follow the wizard
or for silent run use these arguments$ bash ci-work/00-prepare.sh --ACTION=b

1.  Compile the project:
    $bash ci-work/01-compile.sh              # And follow the wizard
or for silent run use these arguments$ bash ci-work/01-compile.sh --CLEAN_BUILD_DIR=y

1.  Run the tests. This stage will also generate reports about

- The list of tests and their reults
- Tests Coverage
- Code Quality
  The reports may be found in the folder ./ci-artifacts/

\$ bash ci-work/02-tests.sh # No additional arguments are required

3.  Build Docker images
    $bash ci-work/03-build.sh
or for silent run use these arguments$ bash ci-work/03-build.sh --ACTION=b

4.  Deploy on localhost of the just compiled Docker Images
    $bash ci-work/04-deploy.sh               # And follow the wizard
or for silent run use these arguments$ bash ci-work/04-deploy.sh --TARGET=. --ACTION=ius --COMPONENTS_TO_UPDATE=a --XUVER_APP_IMAGETAG=000 --COMPONENTS=pivaswd --SILENT

5.  Scan for security vulnerabilities the deployment
    $bash ci-work/05-scan-deploy.sh          # And follow the wizard
or for silent run use these arguments$ bash ci-work/04-deploy.sh --TARGET_URL: https://app.xuver.local

=====================
How to migrate from Bitbucket?

1. If you use HTTPS to pull/push then you must have this result:
   \$ git remote -v
   origin https://bitbucket.org/xuver/app.git (fetch)
   origin https://bitbucket.org/xuver/app.git (push)

Then run this command to use internal GitLab repository
\$ git remote set-url origin https://gitlab.dev.xuver.com:4000/xuver/app.git

Check the results with
\$ git remote -v
origin https://gitlab.dev.xuver.com:4000/xuver/app.git (fetch)
origin https://gitlab.dev.xuver.com:4000/xuver/app.git (push)

2. If you use SSH to pull/push then this sample command must help you:
   git remote set-url origin git@github.com:user/repository.git

If you use SSH to pull/push, then, PLEASE, update this file with the correct commands to run.

=====================

# Xuver app

---

Dashboard React application.

**Technologies overview**

- React.js
- TypeScript
- Redux, Redux-ORM, Redux-Saga
- Ajax
- Tailwind CSS + Material UI
- Jest, Enzyme for unit and integration test
- Cypress for E2E tests
- eslint
- stylelint
- Docker

**Requirements**

- MacOS, Windows (including WSL), and Linux are supported

## How to

---

### Installation, build and running

# Development mode

```sh

$ npm run start

```

The project will start on https://app.xu.local

# Production

```sh

$ npm run build

```

The project will be served from the dist folder

# Running tests

```sh

$ npm run test

```

for coverage info

```sh

$ npm run test:coverage

```

update snapshots

```sh

$ npm run test:update

```

All the tests are stored in **tests** folder. Coverage data collects in _coverage_ folder.

# E2E Tests

```sh

$ npm run cy:open

```

### Component Documentation

All components are stored and documented in Bit.dev platform for collaboration on atomic components. [Open Collection](https://bit.dev/xuver_applications/viewer)

# How to add and update components in Bit.dev

```sh
bit add src/components/*
```

Then tag and export

```sh
bit tag --all 1.0.0
bit export xuver_applications.viewer
```

# Untracking components

```sh
$ bit untrack hello/world
```

several components:

```sh
$ bit untrack hello/world foo/buzz
```

or untrack all

```sh
$ bit untrack --all
```

# Remove component

```sh
$ bit remove username.your-collection/foo/bar --remote
```

See full Bit.dev documentation (here)[https://docs.bit.dev/docs/add-and-isolate-components#tracking-a-component-with-file-dependencies]
