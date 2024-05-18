fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author "Renewed Scripts | FjamZoo#0001"
description 'Renewed Library for a bundle of functions / scripts for servers to use.'
version '2.0'

shared_script {
    '@ox_lib/init.lua',
    'bridge/load.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}


files {
	'bridge/**/client.lua',
}

dependency 'ox_lib'