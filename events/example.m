#if !M_EV_EXAMPLE
#define M_EV_EXAMPLE

Sys = Import('sys');

Example {
    @start(&proc) {
        Sys.print(proc);
    }
    @stop(&proc) {
        Sys.print(proc);
    }
}

#endif
