# Setting up Mastodon on DigitalOcean Kubernetes

**WORK IN PROGRESS**

**See [Terraform code documentation](./infrastructure/terraform/README.md) for more info on the subject.**

## Introduction

This write-up is meant to be a quick start guide for newcomers (and not only) to set up a Mastodon instance running in a DOKS cluster. It starts with a high-level overview of Mastodon and all involved components. Then, you will be guided through the initial installation and configuration steps. Finally, you should be able to see your final Mastodon instance alive and kicking and also evaluate its performance under heavy load.

[Mastodon](https://docs.joinmastodon.org) is a microblogging platform similar to Twitter. It lets you create small posts (hence the microblogging terminology), follow people, react to other people’s posts, etc. Mastodon is an open-source and actively developed project; thus, it is constantly improved. The main goal is to offer people more freedom and not rely on or depend on big tech companies (in contrast with what happened to Twitter lately).

From an architectural point of view, Mastodon follows a decentralised approach compared to Twitter. It means everyone can run their Mastodon instance all over the world independently and then interconnect with other instances via federation. This approach gives more freedom because you can operate alone or in small groups if desired. But, in the end, it's all about cooperation and "spreading the word" or empowering social media all over the globe.

At its heart, the Mastodon stack is powered by the following components:

1. The main backend is written in Ruby implementing core logic (using the Ruby on Rails framework). It also implements the web frontend for all users.
2. A streaming engine implemented using NodeJS used for real-time feed updates.
3. Sidekiq jobs used by the primary backend to propagate data to other Mastodon instances.
4. An in-memory database (Redis) is used for caching and as data storage for Mastodon Sidekiq jobs.
5. A PostgreSQL database is the primary storage for all posts and media. This is the source of truth for the whole system.
6. An ElasticSearch engine (optionally) is used to index and search for posts you have authored, favorited, or mentioned.
7. S3 storage for the rest of persisted data, such as media caching.

This guide teaches you how to use Helm to deploy the whole Mastodon stack. A Terraform setup is also provided, which you can use by cloning this repository. Using this repository as a Terraform module in your custom project is also possible.
