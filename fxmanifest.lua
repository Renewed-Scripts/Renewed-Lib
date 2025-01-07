fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author "Renewed Scripts"
description 'Renewed Scripts is a collection of functions and classes to help you create more compatability between your scripts.'
version '2.0.7'

shared_script {
    '@ox_lib/init.lua',
    'framework/init.lua'
}

client_scripts {
    'modules/**/client.lua',
    'groups/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/**/server.lua',
    'groups/init.lua'
}


files {
    'init.lua',
    'classes/*.lua',
	'framework/**/client.lua'
}

dependency 'ox_lib'