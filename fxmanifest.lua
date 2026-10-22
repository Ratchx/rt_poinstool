fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'poinstool'
description 'Dev tool for marking points with a radius and exporting them as vec3 / vec4'
author 'btx'
version '1.0.0'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/*',
}

shared_script '@ox_lib/init.lua'

client_scripts {
    'config/client/general.lua',
    'config/client/locale.lua',
    'src/client/modules/*.lua',
    'src/client/init.lua',
}

dependencies {
    'ox_lib',
}
