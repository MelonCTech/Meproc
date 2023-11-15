#include "@/../conf/conf.m"

F = Import('file');
S = Import('sys');
Str = Import('str');

Index {
    @acl() {
        return [
            'index': true,
        ];
    }

    @index() {
        path = S.path('@/../web/index.html');
        f = $F;
        if (!f.open(path, 'r')) {
            R['code'] = 404;
            return 'Page Not Found';
        } fi
        R['headers']['Content-Type'] = 'text/html;charset=UTF-8';
        R['code'] = 200;
        body = f.read(f.size());
        f.close();
        body = Str.replace([
            '{{IP}}': Conf['web']['ip'],
            '{{PORT}}': Conf['web']['port'],
        ], body);
        return body;
    }
}
