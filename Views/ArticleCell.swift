import UIKit
final class ArticleCell: UITableViewCell {
    static let reuseId = "ArticleCell"
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let thumbnailView = UIImageView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let timeLabel = UILabel()
    private let bookmarkButton = UIButton(type: .system)
    private let bottomStackView = UIStackView()
    private let gradientLayer = CAGradientLayer()
    
    var onBookmarkTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = thumbnailView.bounds
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 12).cgPath
    }
    
    // MARK: - Setup
    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        setupContainerView()
        setupThumbnail()
        setupContentStack()
        setupLabels()
        setupBottomStack()
        setupBookmarkButton()
        setupConstraints()
    }
    
    private func setupContainerView() {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.masksToBounds = false
        
        contentView.addSubview(containerView)
    }
    
    private func setupThumbnail() {
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .tertiarySystemBackground
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        
        // Gradient overlay for better text readability
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.locations = [0.5, 1.0]
        thumbnailView.layer.addSublayer(gradientLayer)
        
        containerView.addSubview(thumbnailView)
    }
    
    private func setupContentStack() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        contentStackView.alignment = .leading
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(contentStackView)
    }
    
    private func setupLabels() {
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 3
        titleLabel.textColor = .label
        
        // Author
        authorLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        authorLabel.textColor = .secondaryLabel
        
        // Time
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .tertiaryLabel
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(bottomStackView)
    }
    
    private func setupBottomStack() {
        bottomStackView.axis = .horizontal
        bottomStackView.spacing = 8
        bottomStackView.alignment = .top
        bottomStackView.distribution = .fill
        
        // Create a vertical stack for author and date
        let authorDateStack = UIStackView()
        authorDateStack.axis = .vertical
        authorDateStack.spacing = 4
        authorDateStack.alignment = .leading
        authorDateStack.distribution = .fill
        
        authorDateStack.addArrangedSubview(authorLabel)
        authorDateStack.addArrangedSubview(timeLabel)
        
        bottomStackView.addArrangedSubview(authorDateStack)
        
        // Add spacer to push bookmark button to the right
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bottomStackView.addArrangedSubview(spacer)
    }
    
    private func setupBookmarkButton() {
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        bookmarkButton.tintColor = .tintColor
        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(bookmarkButton)
        
        // Add constraints for bookmark button - fixed at bottom right
        NSLayoutConstraint.activate([
            bookmarkButton.widthAnchor.constraint(equalToConstant: 30),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 30),
            bookmarkButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            bookmarkButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func bookmarkButtonTapped() {
        onBookmarkTapped?()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Thumbnail - larger and more prominent
            thumbnailView.topAnchor.constraint(equalTo: containerView.topAnchor),
            thumbnailView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            thumbnailView.heightAnchor.constraint(equalToConstant: 200),
            
            // Content stack
            contentStackView.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with article: Article, isBookmarked: Bool = false) {
        titleLabel.text = article.title ?? "Untitled"
        authorLabel.text = article.author ?? article.source?.name ?? "Unknown"
        
        // Format published date if available
        if let publishedAt = article.publishedAt {
            timeLabel.text = formatDate(publishedAt)
        } else {
            timeLabel.text = ""
        }
        
        // Update bookmark button state
        bookmarkButton.isSelected = isBookmarked
        
        // Load image
        thumbnailView.image = nil
        if let urlString = article.urlToImage {
            ImageLoader.shared.loadImage(from: urlString) { [weak self] image in
                self?.thumbnailView.image = image
            }
        } else {
            thumbnailView.image = UIImage(systemName: "photo.fill")?.withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
        timeLabel.text = nil
        bookmarkButton.isSelected = false
        onBookmarkTapped = nil
    }
}
