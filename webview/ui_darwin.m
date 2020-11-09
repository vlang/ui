// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

NSString *nsstring(string str) {
  return [[NSString alloc] initWithBytesNoCopy:str.str
                                        length:str.len
                                      encoding:NSUTF8StringEncoding
                                  freeWhenDone:false];
}
