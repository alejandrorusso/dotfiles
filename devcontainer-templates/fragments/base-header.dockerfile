# Base header — shared across all stacks. Sets up FROM, locale, and the
# minimal apt packages every stack needs. Stack-specific apt installs go in
# each stack's root.dockerfile (which runs after this, still as root).

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
