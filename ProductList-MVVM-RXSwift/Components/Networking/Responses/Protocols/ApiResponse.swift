//
//  ApiResponse.swift
//  ProductList-MVVM-RXSwift
//
//  Created by Artem Denis on 08.11.2021.
//

import Foundation

protocol ApiResponse {
    mutating func decode(data: Data)
}
