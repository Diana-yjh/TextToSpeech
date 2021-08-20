//
//  ViewController.swift
//  TextToSpeech
//
//  Created by Yejin Hong on 2021/08/19.
//

import UIKit
import AVFoundation
import Speech //iOS 10.0  이상부터 가능

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var testField: UITextField!
    @IBOutlet weak var speak: UIButton!
    @IBOutlet weak var listen: UIButton!
    
    private var recordedFileURL = URL(fileURLWithPath: "voice.wav", isDirectory: false, relativeTo: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!))
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRunning: Bool = false
    private var output: AVAudioFile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speechRecognizer?.delegate = self
    }
    
    @IBAction func speak(_ sender: Any) {
        if isRunning { // 현재 음성인식이 수행중이라면
            audioEngine.stop() // 오디오 입력을 중단한다.
            recognitionRequest?.endAudio() // 음성인식 역시 중단
            speak.isEnabled = false
            isRunning = false
            speak.setTitle("말하기", for: .normal)
        } else {
            startRecording()
            isRunning = true
            speak.setTitle("말하기 멈추기", for: .normal)
        }
    }
    
    func startRecording() {
        //recognitionTask = SFSpeechRecognitionTask
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        let inputNode = self.audioEngine.inputNode
        
        do {
            //try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.testField.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.listen.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        testField.text = ""
        
    }
    
    @IBAction func listen(_ sender: Any) {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: testField.text!)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1
        var output: AVAudioFile?
        print("utterance = \(utterance)")
        
        synthesizer.speak(utterance)
//        synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
//            guard var pcmBuffer = buffer as? AVAudioPCMBuffer else {
//                fatalError("unknown buffer type: \(buffer)")
//            }
//            if pcmBuffer.frameLength == 0 {
//                print("pcmBuffer = 0")
//            } else {
//                do{
//                    // append buffer to file
//                    if output == nil {
//                        print("output == nil")
//                        print("URL = \(self.recordedFileURL)")
//                        output = try AVAudioFile(
//                            forWriting: self.recordedFileURL,
//                            settings: pcmBuffer.format.settings,
//                            commonFormat: .pcmFormatInt16,
//                            interleaved: false)
//                    }
//                    try self.output?.write(from: pcmBuffer)
//                } catch {
//                    print("error")
//                }
//            }
//        }
    }
}
