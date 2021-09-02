//
//  ViewController.swift
//  TextToSpeech
//
//  Created by Yejin Hong on 2021/08/19.
//

import UIKit
import AVFoundation
import Speech //iOS 10.0  이상부터 가능

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var testField: UITextField!
    @IBOutlet weak var speak: UIButton!
    @IBOutlet weak var listen: UIButton!
    
    private var recordedFileURL = URL(fileURLWithPath: "voice.pcm", isDirectory: false, relativeTo: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!))
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var isRunning: Bool = false
    private var isSpeaking: Bool = false
    private var output: AVAudioFile!
    private let synthesizer = AVSpeechSynthesizer()
    private var arrayForSpeaking: [String] = []
    private var firstWord: String = ""
    private var index: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speechRecognizer?.delegate = self
        synthesizer.delegate = self
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
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try! audioSession.setCategory(.playAndRecord, mode: .spokenAudio ,options: [.defaultToSpeaker ,.allowAirPlay , .allowBluetooth])
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if result != nil {
                self.toCheckIfThereAreAnythingToSpeak(result: result)
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
        
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func toCheckIfThereAreAnythingToSpeak(result: SFSpeechRecognitionResult?) {
        var arrayForResult = result!.bestTranscription.formattedString.split(separator: " ").map{String($0)}
        NSLog("arrayForResult = \(arrayForResult)")
        
       
            if index > arrayForResult.endIndex - 1 {
                print("= = = = = = return printed = = = = = =")
                return
            }
            
            if firstWord == arrayForResult[index] {
                if index == arrayForResult.endIndex - 1 {
                    textToSpeech(text: arrayForResult[index])
                    index += 1
                }
            } else {
                firstWord = arrayForResult[index]
            }
    }
    
    func textToSpeech(text: String){
        print("text = \(text)")
        let speakSynthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1
        speakSynthesizer.speak(utterance)
    }
    
    @IBAction func listen(_ sender: Any) {
        let utterance = AVSpeechUtterance(string: testField.text!)
        
        synthesizer.write(utterance) { (buffer) in
            let audioBuffer = buffer as! AVAudioPCMBuffer
            if audioBuffer.frameLength == 0 {
                NSLog("Finished")
            } else {
                do{
                    if self.output == nil {
                        self.output = try AVAudioFile(forWriting: self.recordedFileURL, settings: audioBuffer.format.settings , commonFormat: .pcmFormatInt16, interleaved: false)
                    }
                    try self.output.write(from: audioBuffer)
                    NSLog("buffer = \(audioBuffer)")
                } catch {
                    print("error")
                }
            }
        }
    }
}
