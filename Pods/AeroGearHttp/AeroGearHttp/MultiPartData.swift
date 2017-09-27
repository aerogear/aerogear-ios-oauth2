/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

/**
Represents a multipart object containing a file plus metadata to be processed during upload.
*/
open class MultiPartData {

    /// The 'name' to be used on the request.
    open var name: String
    /// The 'filename' to be used on the request.
    open var filename: String
    /// The 'MIME type' to be used on the request.
    open var mimeType: String
    /// The actual data to be sent.
    open var data: Data
    
    /**
    Initialize a multipart object using an NSURL and a corresponding MIME type. 
    
    :param: url the url of the local file.
    :param: mimeType the MIME type.
    
    :returns: the newly created multipart data.
    */
    public init(url: URL, mimeType: String) {
        self.name = url.lastPathComponent
        self.filename = url.lastPathComponent
        self.mimeType = mimeType;
        
        self.data = try! Data(contentsOf: url)
    }
    
    /**
    Initialize a multipart object using an NSData plus metadata.
    
    :param: data the actual data to be uploaded.
    :param: name the 'name' to be used on the request.
    :param: filename the 'filename' to be used on the request.
    :param: mimeType the 'MIME type' to be used on the request.
    
    :returns: the newly created multipart data.
    */
    public init(data: Data, name: String, filename: String, mimeType: String) {
        self.data = data;
        self.name = name;
        self.filename = filename;
        self.mimeType = mimeType;
    }
}
