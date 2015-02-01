//
//  DetailViewController.swift
//  AACcess
//
//  Created by Byrdann Fox on 1/30/15.
//  Copyright (c) 2015 ExcepApps, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import JavaScriptCore

public var textData: String! = ""

class DetailViewController: UIViewController, UITextViewDelegate, AVSpeechSynthesizerDelegate {
    
    internal let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    internal var speechPaused: Bool = false
    internal var synthesizer: AVSpeechSynthesizer!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var speakAndPauseButton: UIButton!
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
                
        if let detail: AnyObject = self.detailItem {
            
            if let text = self.textView {
                
                var shortCut = detail.valueForKey("shortCut")!.description + " "
                println(shortCut)
                println(text)
                // ...
                text.text = text.text.stringByAppendingString(textData + " " + shortCut)
                
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        textView.delegate = self
        
        clearButton.exclusiveTouch = true
        clearButton.layer.cornerRadius = 5
        speakAndPauseButton.exclusiveTouch = true
        speakAndPauseButton.layer.cornerRadius = 5
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.configureView()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        textView.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        textView?.becomeFirstResponder()
        
        self.synthesizer = AVSpeechSynthesizer()
        self.synthesizer.delegate = self
        speechPaused = false
        
        if textView.text == "" {
            
            speakAndPauseButton.enabled = false
            
        }
        
    }
    
    func textViewDidChange(textView: UITextView) {
        
        var textString: NSString = textView.text
        var charSet: NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        var trimmedString: NSString = textString.stringByTrimmingCharactersInSet(charSet)
                
        textData = String(trimmedString)
        println(textData)
        
        if trimmedString.length == 0 {
            
            speakAndPauseButton.enabled = false
            
        } else {
            
            speakAndPauseButton.enabled = true
            
        }
        
    }
    
    @IBAction func clearAction(sender: UIButton) {
    
        textView?.text = nil
        
        speakAndPauseButton.enabled = false
        
        self.synthesizer.stopSpeakingAtBoundary(.Immediate)
        
        textData = ""
        
    }
    
    @IBAction func speakAndPauseAction(sender: UIButton) {
    
        var textString:NSString = textView.text
        var charSet:NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        var trimmedString:NSString = textString.stringByTrimmingCharactersInSet(charSet)
        
        if trimmedString.length == 0 {
            
        } else {
            
            if speechPaused == false {
                
                speakAndPauseButton.setTitle("Pause", forState: .Normal)
                self.synthesizer.continueSpeaking()
                speechPaused = true
                
            } else {
                
                speakAndPauseButton.setTitle("Speak", forState: .Normal)
                speechPaused = false
                self.synthesizer.pauseSpeakingAtBoundary(.Immediate)
                
            }
            
            if self.synthesizer.speaking == false {
                
                var text:String = textView!.text
                var utterance:AVSpeechUtterance = AVSpeechUtterance(string:text)
                utterance.rate = 0.02
                self.synthesizer.speakUtterance(utterance)
                
            }
            
        }
    
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        
        speakAndPauseButton.setTitle("Speak", forState: .Normal)
        
        speechPaused = false
        
        var sentenceText: String = textView.text
        
        analyzeText(sentenceText)
        
    }
    
    func analyzeText(text: String) {
        
        let context = JSContext(virtualMachine: JSVirtualMachine())
        
        let path = NSBundle.mainBundle().pathForResource("text-analyzer", ofType: "js")
        
        let content = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)
        
        context.evaluateScript(content)
        
        let analyzeText = context.objectForKeyedSubscript("analyzeText")
        
        analyzeText.callWithArguments([text])
        
        let getSentences = context.objectForKeyedSubscript("getSentences")
        
        let getWordsCount = context.objectForKeyedSubscript("getWordsCount")
        
        let getWordsPerSentence = context.objectForKeyedSubscript("getWordsPerSentence")
        
        let getAverageWordLength = context.objectForKeyedSubscript("getAverageWordLength")
        
        var sentences = getSentences.callWithArguments([]).toNumber()
        var wordsCount = getWordsCount.callWithArguments([]).toNumber()
        var wordsPerSentence = getWordsPerSentence.callWithArguments([]).toNumber()
        var averageWordLength = getAverageWordLength.callWithArguments([]).toNumber()
        
        var dataDic:NSDictionary = [
            "text": text,
            "sentences": sentences,
            "wordsCount": wordsCount,
            "wordsPerSentence": wordsPerSentence,
            "averageWordLength": averageWordLength
        ]
        
        println(dataDic)
        
        // store the dataDic's in an array with CoreData...
        // then add a network listener to send all the data to keen with the below code...
        
        let sentenceSpoken:NSString = "sentence_spoken"
        
        KeenClient.sharedClient().addEvent(dataDic, toEventCollection: sentenceSpoken, error: nil)
        
        KeenClient.sharedClient().uploadWithFinishedBlock({ (Void) -> Void in })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}