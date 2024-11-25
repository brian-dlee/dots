# urlencode

A small utility for transforming an input string into a url encoded string. These
utilities exist for md5, base64, and stuff like that but for some reason not URL
encoding. I need this for tools like Prisma or other tools where a database DSN
is necessary to compute. If your database password happens to have an '@' sign in
it, for instance, it will break URL formats when put into a DSN. This little tool
helps me encode components so I can generate DSNs and other things like it easily.

