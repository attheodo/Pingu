//
//  Rescale.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 4/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

struct Rescale<Type : BinaryFloatingPoint> {
    
    typealias RescaleDomain = (lowerBound: Type, upperBound: Type)
    
    // MARK: - Public Properties
    
    var fromDomain: RescaleDomain
    var toDomain: RescaleDomain
    
    // MARK: - Lifecycle
    
    init(from: RescaleDomain, to: RescaleDomain) {
        
        self.fromDomain = from
        self.toDomain = to
        
    }
    
    // MARK: - Public Methods
    
    public func rescale(_ x: Type )  -> Type {
        return interpolate( uninterpolate(x) )
    }
    
    // MARK: - Private Methods
    
    fileprivate func interpolate(_ x: Type ) -> Type {
        return self.toDomain.lowerBound * (1 - x) + self.toDomain.upperBound * x
    }
    
    fileprivate func uninterpolate(_ x: Type) -> Type {
        
        let b = (self.fromDomain.upperBound - self.fromDomain.lowerBound) != 0 ?
                self.fromDomain.upperBound - self.fromDomain.lowerBound :
                1 / self.fromDomain.upperBound
        return (x - self.fromDomain.lowerBound) / b
        
    }
    
}

