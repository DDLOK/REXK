fx_version 'cerulean'
game 'gta5'
author 'SAN VALLY STATE'
description 'character selector + saved skins per account'
version '1.0.0'

server_scripts { 'server.lua' }
client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependency 'account_ollie'
