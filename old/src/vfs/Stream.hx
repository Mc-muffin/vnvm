package vfs;

import lang.promise.IPromise;
import flash.utils.ByteArray;

class Stream extends StreamBase {
    public function readAllBytesAsync():IPromise<ByteArray> {
        return readBytesAsync(length);
    }
}