ZenDash
=======

A minimal AgileZen dashboard

## DESCRIPTION

Sinatra app to display a periodically refreshed dashboard for your AgileZen project.

At the moment, you get:

- List of users participating
- List of phases in the project (limits if any)
- Chart of time-per-phase for the 5 most recent stories completed

## RUNNING

    git clone https://github.com/spiffxp/zendash.git
    # edit zen_dash.rb to replace YOUR_ZEN_API_KEY
    rackup -p 4567
    open http://localhost:4567

## CAVEATS

This is at present a learning experience to play with AgileZen's new REST API.  You probably don't want to point this at a huge project, because there's no caching.

