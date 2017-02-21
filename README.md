# Kraken

## Dependencies

1. Docker
1. Convox
1. Ruby

## Usage

Put kraken/bin into your path.

Assuming you have a directory "dev-rack" with a kraken.json file:

```bash
cd dev-rack;
kraken;
```

If there's a particular application you want to update ENV vars for, but not
deploy, you can add a `--no-deploy` flag.

```bash
cd dev-rack;
kraken --no-deploy review-rocket;
```

If you want to completely ignore an application (don't update env vars, don't
deploy, etc.), you can add an `--ignore` flag.

```bash
cd dev-rack;
kraken --ignore review-rocket --ignore stormcrow;
```

## What happens

When you run `kraken`, the script looks for a `kraken.json` file in the current
directory. If none is found, the script will exit with an error saying that
there's no such file.

Once the config is loaded, kraken will check which dev-rack the CLI is currently
connected to. If the dev-rack's name matches `/prod/` or `/convox/`, kraken will
assume you've accidentally told it to modify the production rack and will exit
without making any changes.

When that's done, kraken will iterate through each application in your
`kraken.json` **in the order specified in the kraken.json file**. If you told
kraken to ignore an app by passing in an `--ignore` flag (i.e. `kraken --ignore
review-rocket`), kraken will immediately jump to the next application in the
list without creating any resources (database, redis, etc.), updating env vars,
or deploying the app.

Assuming the app was not ignored, kraken will first create each of the resources
specified for the app (databases, redis, etc.). If the resource already exists,
kraken will not create another. The resource's names will follow a pattern:
`app-name-resourcetype-env` (`review-rocket-postgres-dev`, `onix-redis-dev`,
etc.). These resources will be created one at a time, so this may take a while.

Once the resources are created, the convox application is created.

After the convox application is created, kraken will pull down the application's
source code, decrypt any encrypted files using blackbox, and update the dev-rack
ENV vars from the specified ENV file (usually `.env.dev-rack`).

Kraken will then configure application ENV vars which point to convox resources
(i.e. `DATABASE_URL`, `REDIS_URL`, etc.).

Finally, if you have specified that the app `depends_on` another application,
kraken will update ENV vars to point to the dependency (i.e. `NAVIGATOR_URL`)

Each ENV var step will --promote automatically.

After all ENV vars are updated, kraken will `convox deploy --app #{app_name}`
from the source directory, promoting the release when complete. Kraken will
always block until a step is complete.
