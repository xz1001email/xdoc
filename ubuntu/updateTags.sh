

path=./

if [ $# -gt 0 ]; then
    path=$@

fi

if [ -f ./tags ]; then
    #ctags -R `find ./ -name "*.[ch]"`
    #ctags -R `find ./ -name "*.cpp" -o -name "*.c" -o -name "*.h"`

    rm tags
    touch tags

    echo "path: $path"
    find $path -name "*.cpp" -o -name "*.c" -o -name "*.h" -o -name "*.hpp" | xargs ctags -R -a

    echo "tags updated"
else
    echo "no tags found"
fi
