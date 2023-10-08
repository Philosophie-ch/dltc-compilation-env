#! /bin/sh
if [ -f "../../template/1.1/scripts/make.lua" ]; then
    maker="../../template/1.1/scripts/make.lua"
elif [ -f "../../../template/1.1/scripts/make.lua" ]; then
    maker="../../../template/1.1/scripts/make.lua"
fi
if [ -n $maker ]; then
    pandoc lua $maker $@
else
    echo "Can't find the make.lua script."
fi

