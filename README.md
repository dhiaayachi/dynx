# dynx
[![Build Status](https://travis-ci.org/dhiaayachi/dynx.svg?branch=master)](https://travis-ci.org/dhiaayachi/dynx)

Dynamic Docker friendly gateway  

The purpose of the project is to provide a dynamically configurable gateway that is easilly deployable in a docker swarm enviroment.


### Requirements:
- Offer dynamic routing 
- configurable through an easy to use rest api
- No down time to relad configuration
- configuration should be shared by all the nodes but no context is shared between nodes (No node to node communication)
- ...

### Current solution:
The current solution use openresty (NGINX based scriptable gateway) with a redis as a Database. It's based on dns
The NGINX have 2 servers configured:
- server listening on 8888 is for configuration and is used to push an upstream to a redis List ( the key is the desired location/API)
- server listening on 8666 have a wildcard location that will execute a lua (rewrite) script to find the upstream, based on the path 
  and rewrite it to the configured upstream
The current solution is based on https://github.com/tes/lua-resty-router
  
### TODO
- Update the README to add a demo and how to deploy
- Add the ability to remove an upstream
- Add the ability to configure multiple end points for one upstream
- Add a pipeling with tests (specially for LUA scripting)
- ...



