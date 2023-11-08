F = Import('file');
S = Import('sys');

Index {
    @acl() {
        return [
            'index': true,
        ];
    }

    @index() {
        path = S.path('@/index.html');
        f = $F;
	S.print(path);
        if (!f.open(path, 'r')) {
            R['code'] = 404;
            return 'Page Not Found';
        } fi
        R['headers']['Content-Type'] = 'text/html;charset=UTF-8';
        R['code'] = 200;
        body = f.read(f.size());
        f.close();
        return body;
    }
}
