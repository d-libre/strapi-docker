# Database Clients 

## Testing with Docker Compose

I have added this docker compose as the easiest way to try and test this docker image, connecting with the different available database clients provided by Strapi, being: `postgres`, `mysql`, `sqlite`, or `mongo` (for Strapi v3.x.x only)

### Compose Environment File (.env.xx)

For every db client (other than the default `sqlite`) you can find a proper `.env` file containing the configuration values required to connect to the different db containers (included in the docker compose):

- .env.mysql
- .env.postgres
- .env.mongo

You can start the database examples just by running the following `docker compose` command, with the selected database client test environment file: 

```bash
> docker compose --env-file ${ DB-CLIENT-ENV-FILE-HERE } up -d api
```

> 👉 *If you're still using docker compose version 1.29.x (or earlier), you need to use `docker-compose` (with dash) instead of the new `docker compose` command (introduced with [compose V2](https://docs.docker.com/compose/cli-command/#compose-v2-and-the-new-docker-compose-command))*

Example

To test connecting to the containerized **postgres** (included in the compose), you need to `cd` into this repository directory
```bash
> cd /path/to/this/repo/examples/databases
```
and run:
```bash
> docker compose --env-file .env.postgres up -d api
```

or even more conveniently, you could just simply ***source*** the selected `.env.xx` file *exporting* the required environment variables, and therefore be able to run `docker compose` without the env file everytime:

e.g.:

```bash
# enable exporting all env variables set
> set -a
# source the .env file for the db client you want to test
> source .env.postgres
# now every docker compose command will use those values
> docker compose up -d api
```

Now you can check and confirm the 2 containers up and running as expected:

```bash
> docker compose ps
```
```log
NAME                COMMAND                  SERVICE             STATUS                PORTS
postgres            "docker-entrypoint.s…"   postgres            running (healthy)     5432/tcp
strapi              "entrypoint develop"     api                 running (healthy)     0.0.0.0:80->1337/tcp
```

and the logs for both of them are available with the `docker compose logs` command:

```bash
> docker compose logs
```
```log
...
postgres  | 2022-03-05 00:59:31.074 UTC [37] LOG:  database system is ready to accept connections
postgres  |  done
strapi    | 🚀 Strapi 3.6.8
strapi    | DataBase Client: postgres
strapi    | Running yarn develop...
strapi    | yarn run v1.22.17
strapi    | $ strapi develop
postgres  | server started
postgres  | CREATE DATABASE
...
strapi    | Create your first administrator 💻 by going to the administration panel at:
strapi    |
strapi    | ┌─────────────────────────────┐
strapi    | │ http://localhost:1337/admin │
strapi    | └─────────────────────────────┘
strapi    |
strapi    | [2022-03-05T00:59:38.680Z] debug HEAD /admin (16 ms) 200
strapi    | [2022-03-05T00:59:38.685Z] info ⏳ Opening the admin panel
postgres  | PostgreSQL init process complete; ready for start up.
...
```

> This `docker compose logs` command allows you to watch the logs for all of your running *compose services* (simultaneously) in the same log thread.  
> If you add the `-f` flag will keep the logs appearing "live" (continously) while events keep happening.