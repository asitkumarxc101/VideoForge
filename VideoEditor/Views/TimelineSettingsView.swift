import SwiftUI

public struct TimelineSettingsView: View {
    @Binding var enableTransforms: Bool
    @Binding var enableColorAdjustments: Bool
    @Binding var enablePIPOverlay: Bool
    @Binding var enableSticker: Bool
    @Binding var enableText: Bool
    @Binding var activeFilter: CIFilterType
    @Binding var activeLUT: LUTType
    @Binding var transitionType: TransitionType
    @Binding var transitionDuration: Double
    @Binding var timelineFPS: Int
    @Binding var canvasResolution: CanvasResolution
    let onChange: () -> Void
    
    public init(
        enableTransforms: Binding<Bool>,
        enableColorAdjustments: Binding<Bool>,
        enablePIPOverlay: Binding<Bool>,
        enableSticker: Binding<Bool>,
        enableText: Binding<Bool>,
        activeFilter: Binding<CIFilterType>,
        activeLUT: Binding<LUTType>,
        transitionType: Binding<TransitionType>,
        transitionDuration: Binding<Double>,
        timelineFPS: Binding<Int>,
        canvasResolution: Binding<CanvasResolution>,
        onChange: @escaping () -> Void
    ) {
        self._enableTransforms = enableTransforms
        self._enableColorAdjustments = enableColorAdjustments
        self._enablePIPOverlay = enablePIPOverlay
        self._enableSticker = enableSticker
        self._enableText = enableText
        self._activeFilter = activeFilter
        self._activeLUT = activeLUT
        self._transitionType = transitionType
        self._transitionDuration = transitionDuration
        self._timelineFPS = timelineFPS
        self._canvasResolution = canvasResolution
        self.onChange = onChange
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ToggleRow(
                title: "Crop & Scale & Rotate",
                subtitle: "Crop 10%, scale 1.15x, rotate clip 1",
                isOn: $enableTransforms,
                onChange: onChange
            )
            
            ToggleRow(
                title: "Color Corrections",
                subtitle: "Brightness, Contrast, Saturation, Exposure",
                isOn: $enableColorAdjustments,
                onChange: onChange
            )
            
            ToggleRow(
                title: "Video PIP Overlay",
                subtitle: "PIP green video, 15° rotation, 85% opacity",
                isOn: $enablePIPOverlay,
                onChange: onChange
            )
            
            ToggleRow(
                title: "Star Sticker Overlay",
                subtitle: "SF Symbol overlaid on screen",
                isOn: $enableSticker,
                onChange: onChange
            )
            
            ToggleRow(
                title: "Text overlay",
                subtitle: "Renders text on custom Canvas",
                isOn: $enableText,
                onChange: onChange
            )
            
            Divider().padding(.vertical, 4)
            
            PickerSection(title: "Base Canvas Resolution") {
                Picker("Canvas Resolution", selection: $canvasResolution) {
                    ForEach(CanvasResolution.allCases) { res in
                        Text(res.rawValue).tag(res)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: canvasResolution) { onChange() }
            }
            
            PickerSection(title: "Target Playback & Export FPS") {
                Picker("Target FPS", selection: $timelineFPS) {
                    Text("24 FPS (Cinema)").tag(24)
                    Text("30 FPS (Standard)").tag(30)
                    Text("60 FPS (Fluid)").tag(60)
                }
                .pickerStyle(.segmented)
                .onChange(of: timelineFPS) { onChange() }
            }
            
            PickerSection(title: "CI Filter (Clip 1)") {
                Picker("CI Filter", selection: $activeFilter) {
                    ForEach(CIFilterType.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: activeFilter) { onChange() }
            }
            
            PickerSection(title: "LUT Color Grading (Clip 1)") {
                Picker("LUT Grading", selection: $activeLUT) {
                    ForEach(LUTType.allCases) { lut in
                        Text(lut.rawValue).tag(lut)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: activeLUT) { onChange() }
            }
            
            PickerSection(title: "Boundary Transition (At 5.0s)") {
                Picker("Transition", selection: $transitionType) {
                    ForEach(TransitionType.allCases) { trans in
                        Text(trans.rawValue).tag(trans)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: transitionType) { onChange() }
                
                if transitionType != .none {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text(String(format: "%.1f s", transitionDuration))
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Slider(value: $transitionDuration, in: 0.5...2.5, step: 0.1) { _ in
                            onChange()
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Supporting subviews

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { onChange() }
        }
    }
}

struct PickerSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            content
        }
    }
}
