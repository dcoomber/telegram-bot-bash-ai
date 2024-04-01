# telegram-bot-bash-ai

A DeepInfra Telegram Bot based on https://github.com/topkecleon/telegram-bot-bash

## Disclaimers

Be responsible!

1. The contributors to this repository take no responsiblity for the costs that you may incur when setting up and using the services offered by DeepInfra
1. The contributors to this repository take no responsiblity for the setup and security of your Telegram Bot

## Pre-requisites

It is assumed that you are:

1. familiar with Docker, having Docker Desktop / Docker CE installed on your system.
1. familiar with Telegram and using bots within the Telegram ecosystem

## Information

This project includes a DeepInfra API collection created using [Bruno: Opensource IDE for exploring and testing APIs](https://www.usebruno.com/).

Visit https://www.usebruno.com/downloads to download the Bruno installer for your system.

You can use the API collection to explore the available interactions with the DeepInfra ecosystem.

## Getting started

### Step 1:  Create a Telegram Bot with Botfather

Lets not re-invent the wheel!  Follow the steps on [this page](https://github.com/topkecleon/telegram-bot-bash/blob/master/doc/1_firstbot.md).

### Step 2:  Set your bot configuration

Create you `botconfig.jssh` from the example provided in `boconfig.jssh.sample`.

```bash
cp -n botconfig.jssh.sample botconfig.jssh
```

Update the relevant fields based on your Telegram configuration.

#### Testing your bot configuration

Start up your local Docker services (this may be Docker Desktop or Docker CE, depending on your configuration).

```bash
docker compose up -d
```

Visit your bot in Telegram and click the `Start` button.

Your bot should respond with a message such as:  `Hi, you are the first user after startup!`.

### Step 3:  DeepInfra

> This is a paid service.  Make sure to read DeepInfra's documentation before you use their services.

1. Visit https://deepinfra.com/ and register an account
1. Visit your `Dashboard > Settings` and set a reasonable payment limit based on your financial situation
1. Visit your `Dashboard > API Keys` to create an API key for use with this project

## Running your bot

### Set `.env` for Docker and Bruno

```bash
cp -n .env.sample .env
cp -n bruno/.env.sample bruno/.env
```

Edit the above files in your favourite text editor, updating the `DEEPINFRA_API_KEY` key with the key created in the preceding section.

### Start up the bot in Docker

```bash
docker compose up -d
```
