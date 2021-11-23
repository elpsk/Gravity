//
//  Gravity.swift
//  Created by Pasca Alberto
//

import UIKit
import CoreMotion

public class Gravity: NSObject {

    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var motion: CMMotionManager = CMMotionManager()
    private var queue: OperationQueue!

    private var dynamicItems: [UIDynamicItem]
    private var collisionItems: [UIDynamicItem]
    private var boundaryPath: UIBezierPath

    /// Initialize the components
    public init( gravityItems: [UIDynamicItem],
                 collisionItems: [UIDynamicItem]?,
                 referenceView: UIView,
                 boundary: UIBezierPath,
                 queue: OperationQueue? )
    {
        self.dynamicItems = gravityItems

        if let collisionItems = collisionItems {
            self.collisionItems = collisionItems
        } else {
            self.collisionItems = self.dynamicItems
        }

        self.boundaryPath = boundary
        
        if let queue = queue {
            self.queue = queue
        } else {
            self.queue = OperationQueue.current ?? OperationQueue.main
        }

        animator = UIDynamicAnimator(referenceView: referenceView)
        gravity = UIGravityBehavior(items: self.dynamicItems)
    }
    
    /// Enable motion and behaviors
    public func enable() {
        animator.addBehavior(collisionBehavior())
        animator.addBehavior(gravity)
        motion.startDeviceMotionUpdates(to: queue, withHandler: motionHandler)
    }

    /// Disable motion and behaviors
    public func disable() {
        animator.removeAllBehaviors()
        motion.stopDeviceMotionUpdates()
    }
    
    /// Restart motion and behaviors
    public func restart() {
        disable()
        enable()
    }

    private func collisionBehavior() -> UICollisionBehavior {
        let collision = UICollisionBehavior(items: self.collisionItems)
        collision.addBoundary(withIdentifier: "borders" as NSCopying, for: self.boundaryPath)
        return collision
    }

    private func motionHandler( motion: CMDeviceMotion?, error: Error? ) {
        guard let motion = motion else { return }

        let grav: CMAcceleration = motion.gravity
        let x = CGFloat(grav.x)
        let y = CGFloat(grav.y)
        var p = CGPoint(x: x, y: y)

        if let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            if orientation == .landscapeLeft {
                let t = p.x
                p.x = 0 - p.y
                p.y = t
            } else if orientation == .landscapeRight {
                let t = p.x
                p.x = p.y
                p.y = 0 - t
            } else if orientation == .portraitUpsideDown {
                p.x *= -1
                p.y *= -1
            }
        }

        let v = CGVector(dx: p.x, dy: 0 - p.y)
        self.gravity.gravityDirection = v
    }

}
