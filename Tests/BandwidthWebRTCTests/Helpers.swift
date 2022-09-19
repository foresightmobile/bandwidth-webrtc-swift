//
//  File.swift
//  
//
//  Created by user on 18.09.2022.
//

import Foundation

enum StubResult {
    case err(StubState<Error>)
    case value(StubState<Any>)
}

enum StubState<T> {
    case none
    case some(T)
}

