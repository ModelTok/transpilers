# EXTERNAL DEPS (to wire in glue):
# WCESingleLayerOptics.hpp

from math import fmod

struct CThetaLimits {
    var theta_limits: [Float]

    fn init(theta_angles: [Float]) {
        self.theta_limits = calculate_theta_limits(theta_angles)
    }

    fn calculate_theta_limits(theta_angles: [Float]) -> [Float] {
        var results: [Float] = [0]
        for i in range(theta_angles.count - 1) {
            let mid_angle = (theta_angles[i] + theta_angles[i + 1]) / 2
            results.append(mid_angle)
        }
        results.append(90)
        return results
    }

    fn get_theta_limits() -> [Float] {
        return self.theta_limits
    }
}

struct TestBSDFThetaLimtisQuarterBasis {
    var m_thetas: CThetaLimits

    fn setup() {
        let theta_angles = [0, 18, 36, 54, 76.5]
        self.m_thetas = CThetaLimits(theta_angles)
    }

    fn test_quarter_basis() {
        print("Begin Test: Theta limits - quarter basis.")
        let a_limits = self.m_thetas
        let results = a_limits.get_theta_limits()
        let correct_results = [0, 9, 27, 45, 63, 90]
        assert(results.count == correct_results.count)
        for i in range(results.count) {
            assert(abs(results[i] - correct_results[i]) < 1e-6)
        }
    }
}

fn main() {
    var test = TestBSDFThetaLimtisQuarterBasis()
    test.setup()
    test.test_quarter_basis()
}
