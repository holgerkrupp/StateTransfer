//
//  RequestView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct RequestView: View {
    @ObservedObject var request: HTTPRequest
    @ObservedObject var historyStore: RequestHistoryStore
    
    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        GroupBox("Endpoint") {
                            VStack(alignment: .leading, spacing: 10) {
                                EndPointView(
                                    endpoint: $request.url,
                                    method: $request.method
                                ) {
                                    sendRequest()
                                }
                                Toggle(
                                    "Follow redirects",
                                    isOn: $request.follorRedirects
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Authorization") {
                            AuthenticationView(
                                credentials: $request.authorizationCredentials,
                                url: request.url?.host ?? ""
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Headers") {
                            RequestHeaderView(header: $request.header)
                                .frame(minHeight: 170)
                        }

                        GroupBox("Parameters") {
                            RequestParamterView(
                                header: $request.parameters,
                                parameterEncoding: $request.parameterEncoding
                            )
                            .frame(minHeight: 170)
                        }

                        GroupBox("Body") {
                            RequestBodyView(
                                message: $request.body,
                                bodyEncoding: $request.bodyEncoding
                            )
                            .frame(minHeight: 180)
                        }
                    }
                    .padding(16)
                }
                .frame(minWidth: 360, idealWidth: 460, maxWidth: 620)

                ResponseView(request: request)
                    .frame(minWidth: 360, maxWidth: .infinity)
                    .padding(16)
            }

            StatusBarView(request: request) {
                historyStore.record(request)
            }
        }
    }

    private func sendRequest() {
        historyStore.record(request)
        Task {
            await request.run()
        }
    }
}

#Preview {
    @Previewable @State var request: HTTPRequest = .init()

    RequestView(
        request: request,
        historyStore: RequestHistoryStore()
    )
}
