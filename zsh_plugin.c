// zsh_plugin.c
#include <zsh/zsh.h>
#include <zsh/zle.h>

static int
zle_hello_widget(ZLE_INT_T ch)
{
    /* Insert "Hello from C!" at the cursor position */
    zlecs = zlecs; // keep cursor position
    spaceinline(13); // make space for 13 chars
    memcpy((char *)zleline + zlecs, "Hello from C!", 13);
    zlecs += 13;
    return 0;
}

/* Table of ZLE widgets to register */
static struct zle_widget zle_hello_struct = {
    zle_hello_widget,
    0
};

static struct builtin bintab[] = {};

/* Table of ZLE widgets for module registration */
static struct zlewidget zlewidgettab[] = {
    { "zle-hello", zle_hello_widget, 0 },
};

int
setup_(Module m)
{
    return 0;
}

int
boot_(Module m)
{
    /* Register the ZLE widget */
    return addzlefunction("zle-hello", zle_hello_widget, 0);
}

int
cleanup_(Module m)
{
    /* Unregister the ZLE widget */
    deletezlefunction("zle-hello");
    return 0;
}

int
finish_(Module m)
{
    return 0;
} 