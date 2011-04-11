ZenDash -- A minimal AgileZen dashboard
=======================================

## DESCRIPTION

Sinatra app to display a periodically refreshed dashboard for your AgileZen project.

At the moment, you get:
- List of users participating
- List of phases in the project (limits if any)
- Chart of time-per-phase for the 5 most recent stories completed

## RUNNING

- Clone the repo
- Edit `app.rb` to replace `YOUR_ZEN_API_KEY`
- Ensure the `rest-client`, `haml`, and `sinatra` gems are installed
- `ruby -rubygems app.rb`

## CAVEATS

This is at present a learning experience to play with AgileZen's new REST API.  You probably don't want to point this at a huge project, because there's no caching.

