declare process: {
    cwd: () -> string,
    chdir: (dir: string) -> (),
    pid: number,
    getpid: () -> number,
    exit: (code: number) -> (),
    env: {[string]: string},
    args: {string},
    os: string,
    arch: string,
    spawn: (cmd: string, args: {string}) -> {exitcode: number, stdout: string, stderr: string}?,
}

declare fs: {
    cwd: () -> string,
    readFile: (path: string) -> string,
    writeFile: (path: string, content: string) -> (),
    appendFile: (path: string, content: string) -> (),
    removeFile: (path: string) -> (),
    readDir: (path: string) -> {string},
    removeDir: (path: string) -> (),
    copy: (src: string, dest: string) -> (),
    move: (src: string, dest: string) -> (),
    isFile: (path: string) -> boolean,
    isDir: (path: string) -> boolean,
    exists: (path: string) -> boolean,
    metadata: (path: string) -> {
        exists: boolean,
        isFile: boolean,
        isDirectory: boolean,
        size: number,
        modified: number?,
        created: number?,
        permissions: {readOnly: boolean}?,
    }?,
}

declare net: {
    request: (opts: {url: string, method: string, headers: {[string]: string}?, body: string?}) -> {status: number, statusCode: number?, headers: {[string]: string}, body: string},
    get: (url: string, headers: {[string]: string}?) -> {status: number, headers: {[string]: string}, body: string},
    serve: (port: number, handler: (req: any) -> any) -> {stop: () -> ()},
}

declare json: {
    encode: (val: any) -> string,
    decode: (str: string) -> any,
    pretty: (val: any) -> string,
}
