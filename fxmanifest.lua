fx_version 'cerulean'
game 'gta5'

name        'spz-rpc'
description 'SPiceZ Discord Rich Presence — live race status, position, class, and track in Discord'
version '1.0.2'
author      'SPiceZ-Core'

shared_scripts {
  'config.lua',
}

client_scripts {
  'client/main.lua',
}

dependencies {
  'ox_lib',
  'spz-core',
}
