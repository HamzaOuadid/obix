import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MarkdownPipe } from '../../pipes/markdown.pipe';

@Component({
  selector: 'app-terms-of-service',
  standalone: true,
  imports: [CommonModule, MarkdownPipe],
  templateUrl: './terms-of-service.component.html',
  styleUrl: './terms-of-service.component.scss'
})
export class TermsOfServiceComponent {
  termsContent = `
# 1. Introduction and Agreement

These Terms of Service ("Terms") constitute a legally binding agreement between you ("User," "you," or "your") and OBIX Financial Intelligence, Inc. ("OBIX," "we," "us," or "our") governing your access to and use of the OBIX platform, including our website, mobile applications, APIs, and all related services (collectively, the "Service").

By accessing or using the Service, you agree to be bound by these Terms, our Privacy Policy, and any additional terms that may apply to specific features of the Service. If you do not agree to these Terms, you may not access or use the Service.

We reserve the right to modify these Terms at any time. If we make changes, we will provide notice by updating the date at the top of these Terms and, in some cases, provide additional notice (such as adding a statement to our website or sending you a notification). Your continued use of the Service after the changes have been made will constitute your acceptance of the changes.

# 2. Eligibility and Registration

You must be at least 18 years old and have the legal capacity to enter into these Terms to use our Service. By using the Service, you represent and warrant that you meet these requirements.

To access certain features of the Service, you may be required to register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete. You are solely responsible for safeguarding your account credentials and for all activity that occurs under your account. You agree to notify us immediately of any unauthorized use of your account.

We reserve the right to suspend or terminate your account, refuse service, or reject or remove content, at our sole discretion, without notice or liability to you.

# 3. Financial Services Disclaimer

OBIX provides sophisticated financial analysis tools that process market data and deliver investment insights. However, it is crucial to understand that our Service constitutes **information and analytics only** and should not be considered:

* Investment advice
* Financial advice
* Banking advice
* Legal advice
* Tax advice
* Insurance advice

Our algorithmic analyses and insights are provided for informational purposes only. Before making any financial decisions, you should consult with qualified financial professionals who can provide advice tailored to your specific circumstances, financial situation, and needs.

OBIX is not a registered investment advisor, broker-dealer, financial institution, or financial services provider. We do not endorse, recommend, or ensure the appropriateness of any specific investment, strategy, or course of action.

# 4. OBIX Service Offerings

Our Service provides computational analysis of financial markets and economic systems through various proprietary algorithms and methodologies. These offerings may include, but are not limited to:

* Market trend analyses
* Volatility assessments
* Pattern recognition
* System anomaly detection
* Historical market correlations
* Custom financial simulations
* Educational materials

We may update, modify, or discontinue any aspect of the Service at any time without prior notice. We make no guarantee regarding the availability, accuracy, or reliability of the Service.

# 5. User Responsibilities and Acceptable Use

When using the Service, you agree to:

* Comply with all applicable laws and regulations
* Maintain the confidentiality of your account credentials
* Notify us immediately of any unauthorized use of your account
* Use the Service only for lawful purposes
* Not interfere with or disrupt the Service or servers connected to the Service
* Not circumvent, disable, or otherwise interfere with security-related features of the Service
* Not attempt to reverse engineer any portion of the Service
* Not collect or harvest user data without permission
* Not upload or distribute malware or other malicious code

You are solely responsible for all activity that occurs under your account, including any data or content you submit through the Service.

# 6. Intellectual Property Rights

All content, features, and functionality of the Service, including but not limited to all information, software, text, displays, images, video, audio, design, selection, arrangement, and algorithms are owned by OBIX, its licensors, or other providers of such material and are protected by United States and international copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws.

Nothing in these Terms transfers any rights, title, or interest in the Service from us to you, except for the limited license granted below.

Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to access and use the Service for your personal, non-commercial use only.

You may not:

* Reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store, transmit, sell, rent, lease, lend, or sublicense any of the material on our Service
* Use any illustrations, photographs, video or audio sequences, or any graphics separately from the accompanying text
* Delete or alter any copyright, trademark, or other proprietary rights notices from copies of materials from the Service
* Access or use for any commercial purposes any part of the Service or any services or materials available through the Service

# 7. Privacy and Data Usage

Your privacy is important to us. Our Privacy Policy, which is incorporated into these Terms by reference, explains how we collect, use, and disclose information about you in connection with the Service. By using the Service, you consent to our collection, use, and disclosure of information as described in our Privacy Policy.

You understand that through your use of the Service, you consent to the collection and use of your data and information, including the transfer of this data and information to the United States and/or other countries for storage, processing, and use by OBIX and its affiliates.

We implement reasonable security measures to protect your personal information; however, we cannot guarantee its absolute security. You acknowledge that you provide your personal information at your own risk.

# 8. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT WILL OBIX, ITS AFFILIATES, DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, SUPPLIERS, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, PUNITIVE, OR EXEMPLARY DAMAGES, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES, REGARDLESS OF LEGAL THEORY, WHETHER OR NOT OBIX HAS BEEN WARNED OF THE POSSIBILITY OF SUCH DAMAGES, AND EVEN IF A REMEDY FAILS OF ITS ESSENTIAL PURPOSE.

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE AGGREGATE LIABILITY OF OBIX TO YOU FOR ALL CLAIMS ARISING OUT OF OR RELATING TO THE USE OF OR INABILITY TO USE THE SERVICE OR OTHERWISE UNDER THESE TERMS, WHETHER IN CONTRACT, TORT, OR OTHERWISE, IS LIMITED TO THE AMOUNT PAID BY YOU TO OBIX FOR THE SERVICE DURING THE 12 MONTHS IMMEDIATELY PRECEDING THE DATE OF THE EVENT GIVING RISE TO THE CLAIM, OR $100, WHICHEVER IS GREATER.

SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF CERTAIN DAMAGES, SO SOME OR ALL OF THE EXCLUSIONS AND LIMITATIONS IN THIS SECTION MAY NOT APPLY TO YOU.

# 9. Disclaimer of Warranties

THE SERVICE AND ALL CONTENT, FUNCTIONS, AND MATERIALS MADE AVAILABLE THROUGH THE SERVICE ARE PROVIDED "AS IS," "AS AVAILABLE," WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.

OBIX DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED OR ERROR-FREE, THAT DEFECTS WILL BE CORRECTED, OR THAT THE SERVICE OR THE SERVERS THAT MAKE IT AVAILABLE ARE FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS. OBIX DOES NOT WARRANT OR MAKE ANY REPRESENTATIONS REGARDING THE USE OR THE RESULTS OF THE USE OF THE SERVICE IN TERMS OF THEIR CORRECTNESS, ACCURACY, RELIABILITY, OR OTHERWISE.

OBIX MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, ABOUT THE COMPLETENESS, ACCURACY, RELIABILITY, SUITABILITY, OR AVAILABILITY WITH RESPECT TO THE SERVICE OR THE INFORMATION, PRODUCTS, SERVICES, OR RELATED GRAPHICS CONTAINED ON THE SERVICE FOR ANY PURPOSE.

# 10. Governing Law and Dispute Resolution

These Terms and any dispute or claim arising out of or in connection with them or their subject matter or formation (including non-contractual disputes or claims) shall be governed by and construed in accordance with the laws of the State of Delaware, without giving effect to any choice or conflict of law provision or rule.

Any legal suit, action, or proceeding arising out of, or related to, these Terms or the Service shall be instituted exclusively in the federal courts of the United States or the courts of the State of Delaware, in each case located in the City of Wilmington and County of New Castle, although we retain the right to bring any suit, action, or proceeding against you for breach of these Terms in your country of residence or any other relevant country.

You waive any and all objections to the exercise of jurisdiction over you by such courts and to venue in such courts.

ANY CAUSE OF ACTION OR CLAIM YOU MAY HAVE ARISING OUT OF OR RELATING TO THESE TERMS OR THE SERVICE MUST BE COMMENCED WITHIN ONE (1) YEAR AFTER THE CAUSE OF ACTION ACCRUES, OTHERWISE, SUCH CAUSE OF ACTION OR CLAIM IS PERMANENTLY BARRED.

# 11. Termination

We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.

If you wish to terminate your account, you may simply discontinue using the Service or contact us to request account deletion.

All provisions of the Terms which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity and limitations of liability.

# 12. Miscellaneous

These Terms constitute the entire agreement between you and OBIX regarding the Service and supersede all prior and contemporaneous written or oral agreements between you and OBIX.

Our failure to exercise or enforce any right or provision of these Terms shall not operate as a waiver of such right or provision.

If any provision of these Terms is held to be invalid or unenforceable, such provision shall be struck and the remaining provisions shall be enforced.

You may not assign your rights under these Terms without our prior written consent, and any attempted assignment will be null and void. We may freely assign our rights and obligations under these Terms.

The section titles in these Terms are for convenience only and have no legal or contractual effect.

# 13. Contact Information

If you have any questions about these Terms, please contact us at:

OBIX Financial Intelligence, Inc.
1234 Market Street, Suite 500
San Francisco, CA 94103
Email: legal@obixfinancial.com
  `;

  constructor(private router: Router) {}

  goBack(): void {
    this.router.navigate(['/login']);
  }
}
