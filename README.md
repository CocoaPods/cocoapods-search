# cocoapods-search

[![Build Status](https://travis-ci.org/CocoaPods/cocoapods-search.svg)](https://travis-ci.org/CocoaPods/cocoapods-search)

CocoaPods plugin that allows you to search your pod spec repository for specific pods matching a query.

## Installation

    $ gem install cocoapods-search

## Usage

    $ pod search QUERY

### Options

You can use the following options with the search command.

| Flag      | Description |
|-----------|-------------|
| `--regex` | Interpret the `QUERY` as a regular expression |
| `--full`  | Search by name, summary, and description |
| `--stats` | Show additional stats (like GitHub watchers and forks) |
| `--ios`   | Restricts the search to Pods supported on iOS |
| `--osx`   | Restricts the search to Pods supported on OS X |
| `--web`   | Searches on cocoapods.org |
