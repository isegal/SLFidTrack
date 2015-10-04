//
//  NetworkingWrapper.hpp
//
//  Created by IvgeniSegal on 10/4/15.
//  Copyright © 2015 Ivgeni Segal. All rights reserved.
//

#ifndef NetworkingWrapper_hpp
#define NetworkingWrapper_hpp

class NetworkingWrapper {
    NetworkingWrapper() =default;
    NetworkingWrapper(NetworkingWrapper&) =delete;
    NetworkingWrapper& operator=(NetworkingWrapper&) =delete;
    
    void setup();
    void update();
    void shutdown();
    
public:
    
};

#endif /* NetworkingWrapper_hpp */
