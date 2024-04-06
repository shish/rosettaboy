export function hex(d: number, len: number) {
    return d.toString(16).padStart(len, "0").toUpperCase();
}
