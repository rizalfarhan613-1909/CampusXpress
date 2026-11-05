// Deklarasi modul aset non-kode.
// TypeScript 6.x menyalakan `noUncheckedSideEffectImports` secara default, sehingga
// impor efek-samping CSS (mis. `./globals.css` dan `leaflet/dist/leaflet.css`)
// menghasilkan TS2882 tanpa deklarasi berikut.
declare module '*.css';
declare module '*.scss';
declare module '*.sass';
declare module '*.less';
