//
//  Mocker.swift
//  ios-swift-start
//
//  Created by alopezh on 04/06/2021.
//  Copyright © 2021 com.herranz.all. All rights reserved.
//

import Foundation
import XCTest

class SwiftMock {
	private var mockedFuncs: [String: MockedFuncCall] = [:]

	private var name: String

	init(_ name: String) {
		self.name = name
	}

	func registerMock(_ fun: String, responses: [Any?]? = nil) {
		mockedFuncs[fun] = MockedFuncCall(name: fun, responses: responses)
	}

	func verify(_ fun: String, called: VerifyCount = .atLeastOnce) -> MockedFuncCall? {
		if let mockedFunc = mockedFuncs[fun] {
			mockedFunc.verify(called: called)
			return mockedFunc
		}

		if case .never = called {
			return nil
		}

		XCTFail("Method \(fun) not called")
		return nil
	}

	func paramCaptured(_ fun: String, position: Int = 0) -> [String: Any?]? {
		if let mock = mockedFuncs[fun] {
			return mock.getCapturedParams(position: position)
		}
		return nil
	}

	func call(_ fun: String, params: [String: Any?]? = nil) -> Any? {
		if let mockedFunc = mockedFuncs[fun] {
			return mockedFunc.call(params: params)
		}
		registerMock(fun)
		return call(fun, params: params)
	}
	
	func callWithError(_ fun: String, params: [String: Any?]? = nil) throws -> Any? {
		if let mockedFunc = mockedFuncs[fun] {
			return try mockedFunc.callWithError(params: params)
		}
		registerMock(fun)
		return try callWithError(fun, params: params)
	}

	func verifyNoMoreInteractions() {
		mockedFuncs.values.forEach { $0.verifyNoMoreInteractions(className: name) }
	}
}

enum VerifyCount {
	case atLeastOnce
	case moreThan(Int)
	case lessThan(Int)
	case exact(Int)
	case never
}

enum When {
	case after
	case before
}

class MockedFuncCall {
	private var name: String
	private var callCount: Int = 0
	private var responses: [Any?]?
	private var paramList: [[String: Any?]?] = []
	private var verifiedCount = 0
	private var timeStamps: [Date] = []

	init(name: String, responses: [Any?]?) {
		self.name = name
		self.responses = responses
	}

	private func getCurrentResponse() -> Any? {
		if let responses = responses, callCount >= responses.count {
			return responses[responses.count - 1]
		}
		return responses?[callCount]
	}

	func call(params: [String: Any?]?) -> Any? {
		let response = getCurrentResponse()
		paramList.append(params)
		timeStamps.append(Date())
		callCount += 1
		return response
	}
	
	func callWithError(params: [String: Any?]?) throws -> Any? {
		let response = call(params: params)
		if response is Error {
			throw response as! Error
		}
		return response
	}

	func getCapturedParams(position: Int) -> [String: Any?]? {
		if position > paramList.count {
			return nil
		}
		return paramList[position]
	}

	func verify(called: VerifyCount = .atLeastOnce) {
		switch called {
		case .atLeastOnce:
			verifiedCount += 1
			if callCount < 1 {
				XCTFail("Func \(name) not called at least once: \( callCount)")
			}
		case .moreThan(let times):
			verifiedCount += times
			if callCount <= times {
				XCTFail("Func \(name) not called more than \(times) times: \( callCount) ")
			}
		case .lessThan(let times):
			verifiedCount += times
			if callCount >= times {
				XCTFail("Func \(name) not called less than \(times) times: \( callCount)")
			}
		case .exact(let times):
			verifiedCount += times
			if callCount != times {
				XCTFail("Func \(name) not called \(times) times: \( callCount)")
			}
		case .never:
			if callCount > 0 {
				XCTFail("Func \(name) is called and it souldn't: \( callCount)")
			}
		}
	}

	func verifyNoMoreInteractions(className: String?) {
		let className = className ?? ""
		if callCount > verifiedCount {
			XCTFail("Func \(className).\(name) received more interactions: \(callCount) than verified \(verifiedCount)")
		}
	}

	func verify(called: When = .before, _ funcCall: MockedFuncCall?, time: Int = 0) {
		if let funcCall = funcCall {
			switch called {
			case .after:
				if timeStamps[time] < funcCall.timeStamps[time] {
					XCTFail("Func \(name) is called before \(funcCall.name) and it should be caled after")
				}
			case .before:
				if timeStamps[time] > funcCall.timeStamps[time] {
					XCTFail("Func \(name) is called after \(funcCall.name) and it should be called before")
				}
			}
		} else {
			XCTFail("Second func never called")
		}
	}
}

