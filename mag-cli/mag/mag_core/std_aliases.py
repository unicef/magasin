"""
Standard aliases for mag commands.

Sometimes it is difficult to remember if it is add, create or new the command. Aliases 
provide an

Aliases are also useful to help advanced users to work more efficiently. 
For example, instead of typing the "mag minio add bucket mybucket" command, 
you can just type "mag m a b mybucket".

This package defines some standard aliases which can be used consistently across the whole mag 
command line interface

Example: 
>>> from click_aliases import ClickAliasedGroup
>>> from mag.mag import cli
>>> cli.group('add', cls=ClickAliasedGroup, aliases=std_aliases.add)
>>> def add():
>>>    pass

This enables all these commands to be the same
```sh
mag add
mag a
mag create
mag c
mag new
mag n
"""

add=["a","create","c","new",'n']
"""
add command. Add a new item, create something.
"""

shell=['sh','bash','console','cmd']
"""
shell command. Command line interfaces
"""
